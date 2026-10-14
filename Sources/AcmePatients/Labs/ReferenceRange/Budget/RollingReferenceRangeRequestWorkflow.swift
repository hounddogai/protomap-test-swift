import AcmePlatform
import Foundation

extension Labs {
    /// Moves rolling reference range requests through their life cycle and keeps a journal of what it did.
    final class RollingReferenceRangeRequestDesk {
        var store: any RollingReferenceRangeRequestStore
        var validator: RollingReferenceRangeRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingReferenceRangeRequestEngine

        init(store: any RollingReferenceRangeRequestStore, validator: RollingReferenceRangeRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingReferenceRangeRequestEngine) {
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
                throw Kit.Failure("rolling reference range request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingReferenceRangeRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling reference range request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingReferenceRangeRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling reference range request \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newRollingReferenceRangeRequestDesk(_ store: any RollingReferenceRangeRequestStore, clock: any Kit.Clocks.Clock) -> RollingReferenceRangeRequestDesk {
        return RollingReferenceRangeRequestDesk(
            store: store,
            validator: defaultRollingReferenceRangeRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingReferenceRangeRequestEngine()
        )
    }
}
