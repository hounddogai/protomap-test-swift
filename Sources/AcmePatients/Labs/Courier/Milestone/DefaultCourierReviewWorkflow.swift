import AcmePlatform
import Foundation

extension Labs {
    /// Moves default courier reviews through their life cycle and keeps a journal of what it did.
    final class DefaultCourierReviewDesk {
        var store: any DefaultCourierReviewStore
        var validator: DefaultCourierReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCourierReviewEngine

        init(store: any DefaultCourierReviewStore, validator: DefaultCourierReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCourierReviewEngine) {
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
                throw Kit.Failure("default courier review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCourierReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCourierReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier review \(code) not found")
            }
            let result = engine.price(item)
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

    static func newDefaultCourierReviewDesk(_ store: any DefaultCourierReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCourierReviewDesk {
        return DefaultCourierReviewDesk(
            store: store,
            validator: defaultDefaultCourierReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCourierReviewEngine(flags)
        )
    }
}
