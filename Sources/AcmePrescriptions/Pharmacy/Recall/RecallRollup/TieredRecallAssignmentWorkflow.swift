import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves tiered recall assignments through their life cycle and keeps a journal of what it did.
    final class TieredRecallAssignmentService {
        var store: any TieredRecallAssignmentStore
        var validator: TieredRecallAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRecallAssignmentEngine

        init(store: any TieredRecallAssignmentStore, validator: TieredRecallAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRecallAssignmentEngine) {
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
                throw Kit.Failure("tiered recall assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRecallAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered recall assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRecallAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered recall assignment \(code) not found")
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

    static func newTieredRecallAssignmentService(_ store: any TieredRecallAssignmentStore, clock: any Kit.Clocks.Clock) -> TieredRecallAssignmentService {
        return TieredRecallAssignmentService(
            store: store,
            validator: defaultTieredRecallAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRecallAssignmentEngine()
        )
    }
}
