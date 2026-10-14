import AcmePlatform
import Foundation

extension Labs {
    /// Moves result overrides through their life cycle and keeps a journal of what it did.
    final class ResultOverrideWorkflow {
        var store: any ResultOverrideStore
        var validator: ResultOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ResultOverrideEngine

        init(store: any ResultOverrideStore, validator: ResultOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ResultOverrideEngine) {
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
                throw Kit.Failure("result override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultOverrideStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultOverrideStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("result override \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newResultOverrideWorkflow(_ store: any ResultOverrideStore, clock: any Kit.Clocks.Clock) -> ResultOverrideWorkflow {
        return ResultOverrideWorkflow(
            store: store,
            validator: defaultResultOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultResultOverrideEngine()
        )
    }
}
