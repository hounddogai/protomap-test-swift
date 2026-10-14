import AcmePlatform
import Foundation

extension Consent {
    /// Moves capped witness tiers through their life cycle and keeps a journal of what it did.
    final class CappedWitnessTierCoordinator {
        var store: any CappedWitnessTierStore
        var validator: CappedWitnessTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedWitnessTierStore, validator: CappedWitnessTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped witness tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedWitnessTierStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped witness tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedWitnessTierStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newCappedWitnessTierCoordinator(_ store: any CappedWitnessTierStore, clock: any Kit.Clocks.Clock) -> CappedWitnessTierCoordinator {
        return CappedWitnessTierCoordinator(
            store: store,
            validator: defaultCappedWitnessTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
