// custom/interfaces/DrillControl.js
import { useBackend } from '../backend';
import { Button, Section, ProgressBar, Box, Flex } from '../components';
import { Window } from '../layouts';

export const DrillControl = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    active,
    status,
    malfunction,
    metal_attached,
    broken,
    integrity,
    max_integrity,
    power_level,
    message_log = [],
  } = data;

  // Определяем цвет статуса
  const statusColor =
    broken || malfunction ? 'bad' : active ? 'good' : 'average';

  // Рассчитываем процент целостности
  const integrityPercent = Math.round((integrity / max_integrity) * 100);
  const integrityColor =
    integrityPercent > 50 ? 'good' : integrityPercent > 25 ? 'average' : 'bad';

  return (
    <Window width={500} height={750} resizable theme="hackerman">
      <Window.Content style={{ padding: '10px' }}>
        <Flex>
          {/* Лог сообщений (левая панель) */}
          <Flex.Item width="45%" height={400} mr={1}>
            <Section title="System Log" height="100%" scrollable>
              {message_log.length > 0 ? (
                message_log.map((message, index) => (
                  <Box key={index} color={getMessageColor(message)} mb={1}>
                    {message}
                  </Box>
                ))
              ) : (
                <Box color="label">Waiting for program to respond...</Box>
              )}
            </Section>
          </Flex.Item>

          {/* Основная панель управления (правая часть) */}
          <Flex.Item grow={1}>
            <Flex direction="column" height="100%">
              <Section title="Drill Status" flexGrow="1">
                <Box
                  bold
                  color={statusColor}
                  fontSize="16px"
                  textAlign="center"
                  py={1}
                >
                  {status}
                </Box>

                <Flex mt={2}>
                  <Flex.Item grow={1} mr={1}>
                    <ProgressBar
                      value={integrity}
                      minValue={0}
                      maxValue={max_integrity}
                      color={integrityColor}
                    >
                      Integrity: {integrityPercent}%
                    </ProgressBar>
                  </Flex.Item>
                  <Flex.Item>
                    <ProgressBar
                      value={power_level}
                      minValue={0}
                      maxValue={100}
                      color="yellow"
                    >
                      Power
                    </ProgressBar>
                  </Flex.Item>
                </Flex>

                {broken && <RepairProgress metal_attached={metal_attached} />}

                {malfunction > 0 && !broken && (
                  <Box color="bad" mt={2}>
                    <b>WARNING:</b> {getMalfunctionText(malfunction)}
                  </Box>
                )}
              </Section>

              <Section>
                <Flex>
                  <Flex.Item grow={1}>
                    <Button
                      fluid
                      icon="power-off"
                      fontSize="14px"
                      textAlign="center"
                      selected={active}
                      onClick={() => act('toggle_power')}
                      disabled={broken || malfunction}
                    >
                      {active ? 'STOP DRILL' : 'START DRILL'}
                    </Button>
                  </Flex.Item>
                  <Flex.Item ml={1}>
                    <Button
                      fluid
                      icon="screwdriver-wrench"
                      tooltip="Maintenance Panel"
                      onClick={() => act('open_panel')}
                    />
                  </Flex.Item>
                </Flex>
              </Section>
            </Flex>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

// Определение цвета сообщения по содержанию
const getMessageColor = (message) => {
  if (
    message.includes('ERROR') ||
    message.includes('WARNING') ||
    message.includes('null')
  ) {
    return 'bad';
  }
  if (message.includes('Alert') || message.includes('Notice')) return 'average';
  return 'label';
};

// Остальные вспомогательные функции без изменений
const getMalfunctionText = (malfunction) => {
  switch (malfunction) {
    case 1:
      return 'Laser array damaged!';
    case 2:
      return 'Sensors malfunction!';
    case 3:
      return 'Capacitor failure!';
    case 4:
      return 'Structural damage detected!';
    case 5:
      return 'Calibration required!';
    default:
      return 'Unknown error!';
  }
};

const RepairProgress = (props, context) => {
  const { metal_attached } = props;
  const steps = [
    { label: 'Plating Missing', icon: 'times-circle' },
    { label: 'Plating Attached', icon: 'circle-half-stroke' },
    { label: 'Plating Secured', icon: 'circle-check' },
  ];

  return (
    <Box mt={2}>
      <ProgressBar
        value={metal_attached}
        minValue={0}
        maxValue={2}
        ranges={{
          good: [1.5, 2],
          average: [0.5, 1.5],
          bad: [0, 0.5],
        }}
      >
        Repair Progress
      </ProgressBar>
      <Box textAlign="center" mt={1}>
        Current: {steps[metal_attached].label}
      </Box>
    </Box>
  );
};
