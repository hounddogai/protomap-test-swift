import AcmePlatform
import Foundation

extension Staffing {
    /// Moves adaptive acuity plan claims through their life cycle and keeps a journal of what it did.
    final class AdaptiveAcuityPlanClaimDesk {
        var store: any AdaptiveAcuityPlanClaimStore
        var validator: AdaptiveAcuityPlanClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveAcuityPlanClaimEngine

        init(store: any AdaptiveAcuityPlanClaimStore, validator: AdaptiveAcuityPlanClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveAcuityPlanClaimEngine) {
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
                throw Kit.Failure("adaptive acuity plan claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveAcuityPlanClaimStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive acuity plan claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveAcuityPlanClaimStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive acuity plan claim \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newAdaptiveAcuityPlanClaimDesk(_ store: any AdaptiveAcuityPlanClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveAcuityPlanClaimDesk {
        return AdaptiveAcuityPlanClaimDesk(
            store: store,
            validator: defaultAdaptiveAcuityPlanClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveAcuityPlanClaimEngine(flags)
        )
    }
}
