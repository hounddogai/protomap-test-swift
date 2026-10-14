import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure segments through their life cycle and keeps a journal of what it did.
    final class ClosureSegmentWorkflow {
        var store: any ClosureSegmentStore
        var validator: ClosureSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureSegmentEngine

        init(store: any ClosureSegmentStore, validator: ClosureSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureSegmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureSegmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newClosureSegmentWorkflow(_ store: any ClosureSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClosureSegmentWorkflow {
        return ClosureSegmentWorkflow(
            store: store,
            validator: defaultClosureSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureSegmentEngine(flags)
        )
    }
}
