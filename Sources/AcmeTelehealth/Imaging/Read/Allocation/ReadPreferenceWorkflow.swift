import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read preferences through their life cycle and keeps a journal of what it did.
    final class ReadPreferenceManager {
        var store: any ReadPreferenceStore
        var validator: ReadPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReadPreferenceStore, validator: ReadPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadPreferenceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadPreferenceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newReadPreferenceManager(_ store: any ReadPreferenceStore, clock: any Kit.Clocks.Clock) -> ReadPreferenceManager {
        return ReadPreferenceManager(
            store: store,
            validator: defaultReadPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
