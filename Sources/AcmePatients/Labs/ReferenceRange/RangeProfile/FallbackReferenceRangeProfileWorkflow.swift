import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback reference range profiles through their life cycle and keeps a journal of what it did.
    final class FallbackReferenceRangeProfileWorkflow {
        var store: any FallbackReferenceRangeProfileStore
        var validator: FallbackReferenceRangeProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackReferenceRangeProfileEngine

        init(store: any FallbackReferenceRangeProfileStore, validator: FallbackReferenceRangeProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackReferenceRangeProfileEngine) {
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
                throw Kit.Failure("fallback reference range profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackReferenceRangeProfileStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback reference range profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackReferenceRangeProfileStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback reference range profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newFallbackReferenceRangeProfileWorkflow(_ store: any FallbackReferenceRangeProfileStore, clock: any Kit.Clocks.Clock) -> FallbackReferenceRangeProfileWorkflow {
        return FallbackReferenceRangeProfileWorkflow(
            store: store,
            validator: defaultFallbackReferenceRangeProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackReferenceRangeProfileEngine()
        )
    }
}
