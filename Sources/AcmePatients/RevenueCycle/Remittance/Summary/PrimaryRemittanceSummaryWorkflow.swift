import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary remittance summaries through their life cycle and keeps a journal of what it did.
    final class PrimaryRemittanceSummaryCoordinator {
        var store: any PrimaryRemittanceSummaryStore
        var validator: PrimaryRemittanceSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryRemittanceSummaryEngine

        init(store: any PrimaryRemittanceSummaryStore, validator: PrimaryRemittanceSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryRemittanceSummaryEngine) {
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
                throw Kit.Failure("primary remittance summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryRemittanceSummaryStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary remittance summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryRemittanceSummaryStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary remittance summary \(code) not found")
            }
            let result = engine.run(item)
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

    static func newPrimaryRemittanceSummaryCoordinator(_ store: any PrimaryRemittanceSummaryStore, clock: any Kit.Clocks.Clock) -> PrimaryRemittanceSummaryCoordinator {
        return PrimaryRemittanceSummaryCoordinator(
            store: store,
            validator: defaultPrimaryRemittanceSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryRemittanceSummaryEngine()
        )
    }
}
