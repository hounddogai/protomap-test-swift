import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up scores through their life cycle and keeps a journal of what it did.
    final class FollowUpScoreService {
        var store: any FollowUpScoreStore
        var validator: FollowUpScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpScoreEngine

        init(store: any FollowUpScoreStore, validator: FollowUpScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpScoreEngine) {
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
                throw Kit.Failure("follow up score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpScoreStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpScoreStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up score \(code) not found")
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

    static func newFollowUpScoreService(_ store: any FollowUpScoreStore, clock: any Kit.Clocks.Clock) -> FollowUpScoreService {
        return FollowUpScoreService(
            store: store,
            validator: defaultFollowUpScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpScoreEngine()
        )
    }
}
