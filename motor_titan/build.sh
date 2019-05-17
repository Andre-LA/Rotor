titanc motor.bit_ids motor.entities motor.states motor.storages motor.systems

mv motor/bit_ids.so bit_ids.so
mv motor/entities.so entities.so
mv motor/states.so states.so
mv motor/storages.so storages.so
mv motor/systems.so systems.so

rm motor/bit_ids.c
rm motor/bit_ids.o

rm motor/entities.c
rm motor/entities.o

rm motor/states.c
rm motor/states.o

rm motor/storages.c
rm motor/storages.o

rm motor/systems.c
rm motor/systems.o


