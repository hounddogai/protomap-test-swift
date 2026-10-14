import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves pending bed board reviews through their life cycle and keeps a journal of what it did.
    final class PendingBedBoardReviewWorkflow {
        var store: any PendingBedBoardReviewStore
        var validator: PendingBedBoardReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingBedBoardReviewEngine

        init(store: any PendingBedBoardReviewStore, validator: PendingBedBoardReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingBedBoardReviewEngine) {
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
                throw Kit.Failure("pending bed board review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingBedBoardReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending bed board review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingBedBoardReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending bed board review \(code) not found")
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

    static func newPendingBedBoardReviewWorkflow(_ store: any PendingBedBoardReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingBedBoardReviewWorkflow {
        return PendingBedBoardReviewWorkflow(
            store: store,
            validator: defaultPendingBedBoardReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingBedBoardReviewEngine(flags)
        )
    }
}
