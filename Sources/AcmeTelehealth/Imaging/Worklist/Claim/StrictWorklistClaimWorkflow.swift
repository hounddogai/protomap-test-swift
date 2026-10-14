import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict worklist claims through their life cycle and keeps a journal of what it did.
    final class StrictWorklistClaimDesk {
        var store: any StrictWorklistClaimStore
        var validator: StrictWorklistClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictWorklistClaimEngine

        init(store: any StrictWorklistClaimStore, validator: StrictWorklistClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictWorklistClaimEngine) {
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
                throw Kit.Failure("strict worklist claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictWorklistClaimStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict worklist claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictWorklistClaimStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict worklist claim \(code) not found")
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

    static func newStrictWorklistClaimDesk(_ store: any StrictWorklistClaimStore, clock: any Kit.Clocks.Clock) -> StrictWorklistClaimDesk {
        return StrictWorklistClaimDesk(
            store: store,
            validator: defaultStrictWorklistClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictWorklistClaimEngine()
        )
    }
}
