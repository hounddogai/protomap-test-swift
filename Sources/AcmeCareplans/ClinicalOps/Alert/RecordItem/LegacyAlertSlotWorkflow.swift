import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves legacy alert slots through their life cycle and keeps a journal of what it did.
    final class LegacyAlertSlotCoordinator {
        var store: any LegacyAlertSlotStore
        var validator: LegacyAlertSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyAlertSlotStore, validator: LegacyAlertSlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy alert slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyAlertSlotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy alert slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyAlertSlotStatus.closed)
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

    static func newLegacyAlertSlotCoordinator(_ store: any LegacyAlertSlotStore, clock: any Kit.Clocks.Clock) -> LegacyAlertSlotCoordinator {
        return LegacyAlertSlotCoordinator(
            store: store,
            validator: defaultLegacyAlertSlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
