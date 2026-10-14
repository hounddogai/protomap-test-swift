import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy care gap estimates through their life cycle and keeps a journal of what it did.
    final class LegacyCareGapEstimateDesk {
        var store: any LegacyCareGapEstimateStore
        var validator: LegacyCareGapEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyCareGapEstimateStore, validator: LegacyCareGapEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy care gap estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyCareGapEstimateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy care gap estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyCareGapEstimateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyCareGapEstimateDesk(_ store: any LegacyCareGapEstimateStore, clock: any Kit.Clocks.Clock) -> LegacyCareGapEstimateDesk {
        return LegacyCareGapEstimateDesk(
            store: store,
            validator: defaultLegacyCareGapEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
