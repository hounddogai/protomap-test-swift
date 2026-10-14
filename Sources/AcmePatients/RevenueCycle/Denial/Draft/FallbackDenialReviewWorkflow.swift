import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback denial reviews through their life cycle and keeps a journal of what it did.
    final class FallbackDenialReviewManager {
        var store: any FallbackDenialReviewStore
        var validator: FallbackDenialReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackDenialReviewEngine

        init(store: any FallbackDenialReviewStore, validator: FallbackDenialReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackDenialReviewEngine) {
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
                throw Kit.Failure("fallback denial review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDenialReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDenialReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback denial review \(code) not found")
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

    static func newFallbackDenialReviewManager(_ store: any FallbackDenialReviewStore, clock: any Kit.Clocks.Clock) -> FallbackDenialReviewManager {
        return FallbackDenialReviewManager(
            store: store,
            validator: defaultFallbackDenialReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackDenialReviewEngine()
        )
    }
}
