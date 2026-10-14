import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves fallback interaction digests through their life cycle and keeps a journal of what it did.
    final class FallbackInteractionDigestService {
        var store: any FallbackInteractionDigestStore
        var validator: FallbackInteractionDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackInteractionDigestEngine

        init(store: any FallbackInteractionDigestStore, validator: FallbackInteractionDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackInteractionDigestEngine) {
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
                throw Kit.Failure("fallback interaction digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackInteractionDigestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback interaction digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackInteractionDigestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback interaction digest \(code) not found")
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

    static func newFallbackInteractionDigestService(_ store: any FallbackInteractionDigestStore, clock: any Kit.Clocks.Clock) -> FallbackInteractionDigestService {
        return FallbackInteractionDigestService(
            store: store,
            validator: defaultFallbackInteractionDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackInteractionDigestEngine()
        )
    }
}
