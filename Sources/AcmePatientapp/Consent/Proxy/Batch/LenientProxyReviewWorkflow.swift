import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient proxy reviews through their life cycle and keeps a journal of what it did.
    final class LenientProxyReviewDesk {
        var store: any LenientProxyReviewStore
        var validator: LenientProxyReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientProxyReviewEngine

        init(store: any LenientProxyReviewStore, validator: LenientProxyReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientProxyReviewEngine) {
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
                throw Kit.Failure("lenient proxy review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientProxyReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient proxy review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientProxyReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient proxy review \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newLenientProxyReviewDesk(_ store: any LenientProxyReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientProxyReviewDesk {
        return LenientProxyReviewDesk(
            store: store,
            validator: defaultLenientProxyReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientProxyReviewEngine(flags)
        )
    }
}
