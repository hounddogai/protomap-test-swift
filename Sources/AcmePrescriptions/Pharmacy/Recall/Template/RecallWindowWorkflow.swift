import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall windows through their life cycle and keeps a journal of what it did.
    final class RecallWindowManager {
        var store: any RecallWindowStore
        var validator: RecallWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallWindowStore, validator: RecallWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRecallWindowManager(_ store: any RecallWindowStore, clock: any Kit.Clocks.Clock) -> RecallWindowManager {
        return RecallWindowManager(
            store: store,
            validator: defaultRecallWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
