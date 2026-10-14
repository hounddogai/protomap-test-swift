import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves adaptive discharge plan mappings through their life cycle and keeps a journal of what it did.
    final class AdaptiveDischargePlanMappingWorkflow {
        var store: any AdaptiveDischargePlanMappingStore
        var validator: AdaptiveDischargePlanMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveDischargePlanMappingStore, validator: AdaptiveDischargePlanMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive discharge plan mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveDischargePlanMappingStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive discharge plan mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveDischargePlanMappingStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newAdaptiveDischargePlanMappingWorkflow(_ store: any AdaptiveDischargePlanMappingStore, clock: any Kit.Clocks.Clock) -> AdaptiveDischargePlanMappingWorkflow {
        return AdaptiveDischargePlanMappingWorkflow(
            store: store,
            validator: defaultAdaptiveDischargePlanMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
