import AcmePlatform
import Foundation

extension Consent {
    /// Moves language snapshots through their life cycle and keeps a journal of what it did.
    final class LanguageSnapshotDesk {
        var store: any LanguageSnapshotStore
        var validator: LanguageSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LanguageSnapshotStore, validator: LanguageSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageSnapshotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageSnapshotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLanguageSnapshotDesk(_ store: any LanguageSnapshotStore, clock: any Kit.Clocks.Clock) -> LanguageSnapshotDesk {
        return LanguageSnapshotDesk(
            store: store,
            validator: defaultLanguageSnapshotValidator(),
            clock: clock,
            journal: []
        )
    }
}
