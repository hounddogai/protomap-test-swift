import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves adaptive outreach cycles through their life cycle and keeps a journal of what it did.
    final class AdaptiveOutreachCycleWorkflow {
        var store: any AdaptiveOutreachCycleStore
        var validator: AdaptiveOutreachCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveOutreachCycleEngine

        init(store: any AdaptiveOutreachCycleStore, validator: AdaptiveOutreachCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveOutreachCycleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive outreach cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveOutreachCycleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive outreach cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveOutreachCycleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive outreach cycle \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAdaptiveOutreachCycleWorkflow(_ store: any AdaptiveOutreachCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveOutreachCycleWorkflow {
        return AdaptiveOutreachCycleWorkflow(
            store: store,
            validator: defaultAdaptiveOutreachCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveOutreachCycleEngine(flags)
        )
    }
}
