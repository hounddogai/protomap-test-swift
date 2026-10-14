import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach mappings through their life cycle and keeps a journal of what it did.
    final class OutreachMappingWorkflow {
        var store: any OutreachMappingStore
        var validator: OutreachMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OutreachMappingEngine

        init(store: any OutreachMappingStore, validator: OutreachMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OutreachMappingEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachMappingStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachMappingStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach mapping \(code) not found")
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

    static func newOutreachMappingWorkflow(_ store: any OutreachMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OutreachMappingWorkflow {
        return OutreachMappingWorkflow(
            store: store,
            validator: defaultOutreachMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultOutreachMappingEngine(flags)
        )
    }
}
