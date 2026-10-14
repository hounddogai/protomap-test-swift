import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range baselines through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeBaselineDesk {
        var store: any ReferenceRangeBaselineStore
        var validator: ReferenceRangeBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeBaselineEngine

        init(store: any ReferenceRangeBaselineStore, validator: ReferenceRangeBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeBaselineEngine) {
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
                throw Kit.Failure("reference range baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range baseline \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newReferenceRangeBaselineDesk(_ store: any ReferenceRangeBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferenceRangeBaselineDesk {
        return ReferenceRangeBaselineDesk(
            store: store,
            validator: defaultReferenceRangeBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeBaselineEngine(flags)
        )
    }
}
