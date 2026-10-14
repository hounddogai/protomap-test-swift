import AcmePlatform
import Foundation

extension Referrals {
    /// Moves lenient eligibility estimates through their life cycle and keeps a journal of what it did.
    final class LenientEligibilityEstimateService {
        var store: any LenientEligibilityEstimateStore
        var validator: LenientEligibilityEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientEligibilityEstimateEngine

        init(store: any LenientEligibilityEstimateStore, validator: LenientEligibilityEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientEligibilityEstimateEngine) {
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
                throw Kit.Failure("lenient eligibility estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientEligibilityEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient eligibility estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientEligibilityEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient eligibility estimate \(code) not found")
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

    static func newLenientEligibilityEstimateService(_ store: any LenientEligibilityEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientEligibilityEstimateService {
        return LenientEligibilityEstimateService(
            store: store,
            validator: defaultLenientEligibilityEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientEligibilityEstimateEngine(flags)
        )
    }
}
