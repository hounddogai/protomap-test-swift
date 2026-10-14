import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession milestones through their life cycle and keeps a journal of what it did.
    final class AccessionMilestoneService {
        var store: any AccessionMilestoneStore
        var validator: AccessionMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AccessionMilestoneEngine

        init(store: any AccessionMilestoneStore, validator: AccessionMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AccessionMilestoneEngine) {
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
                throw Kit.Failure("accession milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionMilestoneStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionMilestoneStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession milestone \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newAccessionMilestoneService(_ store: any AccessionMilestoneStore, clock: any Kit.Clocks.Clock) -> AccessionMilestoneService {
        return AccessionMilestoneService(
            store: store,
            validator: defaultAccessionMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultAccessionMilestoneEngine()
        )
    }
}
