import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves regional isolation plans through their life cycle and keeps a journal of what it did.
    final class RegionalIsolationPlanCoordinator {
        var store: any RegionalIsolationPlanStore
        var validator: RegionalIsolationPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalIsolationPlanEngine

        init(store: any RegionalIsolationPlanStore, validator: RegionalIsolationPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalIsolationPlanEngine) {
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
                throw Kit.Failure("regional isolation plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalIsolationPlanStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional isolation plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalIsolationPlanStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional isolation plan \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newRegionalIsolationPlanCoordinator(_ store: any RegionalIsolationPlanStore, clock: any Kit.Clocks.Clock) -> RegionalIsolationPlanCoordinator {
        return RegionalIsolationPlanCoordinator(
            store: store,
            validator: defaultRegionalIsolationPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalIsolationPlanEngine()
        )
    }
}
