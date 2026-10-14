import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves primary rounding slots through their life cycle and keeps a journal of what it did.
    final class PrimaryRoundingSlotCoordinator {
        var store: any PrimaryRoundingSlotStore
        var validator: PrimaryRoundingSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryRoundingSlotStore, validator: PrimaryRoundingSlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary rounding slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryRoundingSlotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary rounding slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryRoundingSlotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newPrimaryRoundingSlotCoordinator(_ store: any PrimaryRoundingSlotStore, clock: any Kit.Clocks.Clock) -> PrimaryRoundingSlotCoordinator {
        return PrimaryRoundingSlotCoordinator(
            store: store,
            validator: defaultPrimaryRoundingSlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
