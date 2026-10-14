import AcmePlatform
import Foundation

extension Imaging {
    /// Moves fallback worklist reviews through their life cycle and keeps a journal of what it did.
    final class FallbackWorklistReviewManager {
        var store: any FallbackWorklistReviewStore
        var validator: FallbackWorklistReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackWorklistReviewEngine

        init(store: any FallbackWorklistReviewStore, validator: FallbackWorklistReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackWorklistReviewEngine) {
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
                throw Kit.Failure("fallback worklist review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackWorklistReviewStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback worklist review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackWorklistReviewStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback worklist review \(code) not found")
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

    static func newFallbackWorklistReviewManager(_ store: any FallbackWorklistReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackWorklistReviewManager {
        return FallbackWorklistReviewManager(
            store: store,
            validator: defaultFallbackWorklistReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackWorklistReviewEngine(flags)
        )
    }
}
