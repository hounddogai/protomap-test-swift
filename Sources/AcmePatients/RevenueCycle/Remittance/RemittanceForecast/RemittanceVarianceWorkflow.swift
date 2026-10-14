import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance variances through their life cycle and keeps a journal of what it did.
    final class RemittanceVarianceCoordinator {
        var store: any RemittanceVarianceStore
        var validator: RemittanceVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceVarianceEngine

        init(store: any RemittanceVarianceStore, validator: RemittanceVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceVarianceEngine) {
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
                throw Kit.Failure("remittance variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceVarianceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceVarianceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance variance \(code) not found")
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

    static func newRemittanceVarianceCoordinator(_ store: any RemittanceVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceVarianceCoordinator {
        return RemittanceVarianceCoordinator(
            store: store,
            validator: defaultRemittanceVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceVarianceEngine(flags)
        )
    }
}
