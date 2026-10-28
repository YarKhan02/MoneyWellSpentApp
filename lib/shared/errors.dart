/// Turns any thrown error into copy that is safe to show a person.
///
/// [FormatException] carries our own validation wording, so it passes through.
/// Anything else is reported generically — financial detail never reaches the
/// UI or logs, and the message always states that existing data is retained.
String friendlyError(Object error) => error is FormatException
    ? error.message
    : 'Could not save this change. Your existing data is retained. Please retry.';
