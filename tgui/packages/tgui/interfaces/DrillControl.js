import { useBackend, useLocalState } from '../backend';
import { Box, Section, Input, ProgressBar, LabeledList } from '../components';
import { Window } from '../layouts';

// Define the malfunction indicators
const MalfunctionIndicator = (props) => {
  const { type, active } = props;
  let letter, color;

  switch (type) {
    case 'laser':
      letter = 'L';
      color = active ? 'bad' : 'good';
      break;
    case 'sensor':
      letter = 'S';
      color = active ? 'bad' : 'good';
      break;
    case 'capacitor':
      letter = 'C';
      color = active ? 'bad' : 'good';
      break;
    case 'calibration':
      letter = 'K';
      color = active ? 'bad' : 'good';
      break;
    default:
      letter = '?';
      color = 'average';
  }

  return (
    <Box
      inline
      width="20px"
      height="20px"
      textAlign="center"
      backgroundColor={color}
      bold
      ml={1}
    >
      {letter}
    </Box>
  );
};

export const DrillControl = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    active,
    integrity,
    max_integrity,
    cell_charge,
    cell_maxcharge,
    message_log = [],
    malfunctions = {},
  } = data;

  const [inputMessage, setInputMessage] = useLocalState(
    context,
    'inputMessage',
    ''
  );

  return (
    <Window title="Mining Drill Control" width={780} height={550}>
      <Window.Content>
        <Box height="100%">
          {/* Left side - Log panel */}
          <Box
            position="absolute"
            width="550px"
            height="650px"
            overflowY="scroll"
            style={{
              'background-color': 'rgba(0, 0, 0, 0.5)',
              'padding': '5px',
            }}
          >
            <Section title="System Log">
              {message_log.map((message, index) => (
                <Box key={index}>{message}</Box>
              ))}
            </Section>
            {/* Панель ввода сообщения */}
            <Section bottom height="60px">
              <Input
                fluid
                placeholder="_"
                value={inputMessage}
                onInput={(e, value) => setInputMessage(value)}
                onEnter={(e, value) => {
                  if (inputMessage.length > 0) {
                    act('manual_command', { message: value });
                    setInputMessage('');
                    setTimeout(() => {
                      document.querySelector('.Input__input').focus();
                    }, 0);
                  }
                }}
              />
            </Section>
          </Box>

          {/* Right side - Control panel */}
          <Box position="absolute" left="560px" width="200px" height="350px">
            <Section title="Drill Status">
              <LabeledList>
                <LabeledList.Item label="Integrity">
                  <ProgressBar
                    value={integrity / max_integrity}
                    ranges={{
                      good: [0.5, 1],
                      average: [0.2, 0.5],
                      bad: [0, 0.2],
                    }}
                  >
                    {integrity}/{max_integrity}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Power Cell">
                  <ProgressBar
                    value={cell_charge / cell_maxcharge}
                    ranges={{
                      good: [0.5, Infinity],
                      average: [0.2, 0.5],
                      bad: [0, 0.2],
                    }}
                  >
                    {cell_charge}/{cell_maxcharge}
                  </ProgressBar>
                </LabeledList.Item>
              </LabeledList>

              {/* Malfunction indicators */}
              <Box mt={2}>
                <Box inline>Status Indicators:</Box>
                <MalfunctionIndicator type="laser" active="good" />
                <MalfunctionIndicator type="sensor" active="good" />
                <MalfunctionIndicator type="capacitor" active="good" />
                <MalfunctionIndicator type="calibration" active="good" />
              </Box>
            </Section>
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};
