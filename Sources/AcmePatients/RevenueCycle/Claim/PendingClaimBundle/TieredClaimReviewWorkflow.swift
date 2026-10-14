import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves tiered claim reviews through their life cycle and keeps a journal of what it did.
    final class TieredClaimReviewDesk {
        var store: any TieredClaimReviewStore
        var validator: TieredClaimReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredClaimReviewEngine

        init(store: any TieredClaimReviewStore, validator: TieredClaimReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredClaimReviewEngine) {
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
                throw Kit.Failure("tiered claim review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredClaimReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered claim review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredClaimReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered claim review \(code) not found")
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

    static func newTieredClaimReviewDesk(_ store: any TieredClaimReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredClaimReviewDesk {
        return TieredClaimReviewDesk(
            store: store,
            validator: defaultTieredClaimReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredClaimReviewEngine(flags)
        )
    }
}
