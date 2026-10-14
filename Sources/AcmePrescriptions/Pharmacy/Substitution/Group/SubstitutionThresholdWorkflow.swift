import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution thresholds through their life cycle and keeps a journal of what it did.
    final class SubstitutionThresholdWorkflow {
        var store: any SubstitutionThresholdStore
        var validator: SubstitutionThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionThresholdEngine

        init(store: any SubstitutionThresholdStore, validator: SubstitutionThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionThresholdEngine) {
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
                throw Kit.Failure("substitution threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionThresholdStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionThresholdStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution threshold \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSubstitutionThresholdWorkflow(_ store: any SubstitutionThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SubstitutionThresholdWorkflow {
        return SubstitutionThresholdWorkflow(
            store: store,
            validator: defaultSubstitutionThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionThresholdEngine(flags)
        )
    }
}
