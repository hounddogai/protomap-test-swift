import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation preferences through their life cycle and keeps a journal of what it did.
    final class RevocationPreferenceCoordinator {
        var store: any RevocationPreferenceStore
        var validator: RevocationPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationPreferenceEngine

        init(store: any RevocationPreferenceStore, validator: RevocationPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationPreferenceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationPreferenceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationPreferenceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation preference \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRevocationPreferenceCoordinator(_ store: any RevocationPreferenceStore, clock: any Kit.Clocks.Clock) -> RevocationPreferenceCoordinator {
        return RevocationPreferenceCoordinator(
            store: store,
            validator: defaultRevocationPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationPreferenceEngine()
        )
    }
}
