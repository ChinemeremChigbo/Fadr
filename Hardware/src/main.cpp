#include <Arduino.h>
#include <ESP32Servo.h>
#include "bletest.h"

// NOTES:

BLEServer *server;
BLECharacteristic *characteristicMessage;
float MM = 40.95;
int MIDPOINT = 700;
int pos = MIDPOINT; // 0-4095

// hbridge controllers:
int enablePin = 27;
int in1Pin = 14;
int in2Pin = 12;

// potentiometer
int potPin = 35;

int pwmOutput = 65535;

int MAX_POSITION = 4095;
int MIN_POSITION = 0;

int servoPin = 4;
Servo myservo; // create servo object to control a servo

class MyServerCallbacks : public BLEServerCallbacks
{
    void onConnect(BLEServer *server)
    {
        Serial.println("Connected");
    };

    void onDisconnect(BLEServer *server)
    {
        Serial.println("Device disconnected, restarting advertising");
        server->startAdvertising();
    }
};

class MessageCallbacks : public BLECharacteristicCallbacks
{
    void onWrite(BLECharacteristic *characteristic)
    {
        std::string data = characteristic->getValue();
        Serial.println(data.c_str());

        int servoValue = atoi(data.c_str());

        // not accurate if it is servo instead of actuator
        servoValue = constrain(servoValue, MIN_POSITION, MAX_POSITION);

        pos = servoValue;
    }

    void onRead(BLECharacteristic *characteristic)
    {
        characteristic->setValue("Foobar");
    }
};

void setExtend()
{
    digitalWrite(in1Pin, LOW);
    digitalWrite(in2Pin, HIGH);
}

void setRetract()
{
    digitalWrite(in1Pin, HIGH);
    digitalWrite(in2Pin, LOW);
}

void setStop()
{
    digitalWrite(in1Pin, LOW);
    digitalWrite(in2Pin, LOW);
}

void setSpeed(int speed) // 0-255
{
    pwmOutput = speed;
    analogWrite(enablePin, pwmOutput);
}

void moveToPosition(int targetPosition)
{ // 0-4095

    int currentPosition = analogRead(potPin);

    // Serial.print("Target: ");
    // Serial.print(targetPosition);
    // Serial.print(", Actual: ");
    // Serial.println(currentPosition);
    if (targetPosition > MAX_POSITION)
    {
        targetPosition = MAX_POSITION;
    }
    if (targetPosition < MIN_POSITION)
    {
        targetPosition = MIN_POSITION;
    }

    if (targetPosition > currentPosition)
    {
        setExtend();
    }
    else if (targetPosition < currentPosition)
    {
        setRetract();
    }
    else
    {
        setStop();
    }
}

void setup()
{
    Serial.begin(115200);

    // Actuator setup
    pinMode(enablePin, OUTPUT);
    pinMode(in1Pin, OUTPUT);
    pinMode(in2Pin, OUTPUT);

    pinMode(potPin, INPUT);

    // Servo setup
    // Allow allocation of all timers
    // ESP32PWM::allocateTimer(0);
    // ESP32PWM::allocateTimer(1);
    // ESP32PWM::allocateTimer(2);
    // ESP32PWM::allocateTimer(3);
    // myservo.setPeriodHertz(50);          // standard 50 hz servo
    myservo.attach(servoPin, 500, 2400); // attaches the servo on pin 18 to the servo object
                                         // using default min/max of 1000us and 2000us
                                         // different servos may require different min/max settings
                                         // for an accurate 0 to 180 sweep

    // Setup BLE Server
    BLEDevice::init(DEVICE_NAME);
    server = BLEDevice::createServer();
    server->setCallbacks(new MyServerCallbacks());

    // Register message service that can receive messages and reply with a static message.
    BLEService *service = server->createService(SERVICE_UUID);
    characteristicMessage = service->createCharacteristic(MESSAGE_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE);
    characteristicMessage->setCallbacks(new MessageCallbacks());
    characteristicMessage->addDescriptor(new BLE2902());
    service->start();

    // Register device info service, that contains the device's UUID, manufacturer and name.
    service = server->createService(DEVINFO_UUID);
    BLECharacteristic *characteristic = service->createCharacteristic(DEVINFO_MANUFACTURER_UUID, BLECharacteristic::PROPERTY_READ);
    characteristic->setValue(DEVICE_MANUFACTURER);
    characteristic = service->createCharacteristic(DEVINFO_NAME_UUID, BLECharacteristic::PROPERTY_READ);
    characteristic->setValue(DEVICE_NAME);
    characteristic = service->createCharacteristic(DEVINFO_SERIAL_UUID, BLECharacteristic::PROPERTY_READ);
    String chipId = String((uint32_t)(ESP.getEfuseMac() >> 24), HEX);
    characteristic->setValue(chipId.c_str());
    service->start();

    // Advertise services
    BLEAdvertising *advertisement = server->getAdvertising();
    BLEAdvertisementData adv;
    adv.setName(DEVICE_NAME);
    adv.setCompleteServices(BLEUUID(SERVICE_UUID));
    advertisement->setAdvertisementData(adv);
    advertisement->start();
    analogWrite(enablePin, pwmOutput);

    Serial.println("Ready");
}

void loop()
{
    int potValue = analogRead(potPin);
    moveToPosition(pos);
    myservo.write(pos);
}