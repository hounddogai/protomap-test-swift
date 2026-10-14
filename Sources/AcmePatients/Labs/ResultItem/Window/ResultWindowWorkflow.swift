import AcmePlatform
import Foundation

extension Labs {
    /// Moves result windows through their life cycle and keeps a journal of what it did.
    final class ResultWindowWorkflow {
        var store: any ResultWindowStore
        var validator: ResultWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ResultWindowEngine

        init(store: any ResultWindowStore, validator: ResultWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ResultWindowEngine) {
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
                throw Kit.Failure("result window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("result window \(code) not found")
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

    static func newResultWindowWorkflow(_ store: any ResultWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ResultWindowWorkflow {
        return ResultWindowWorkflow(
            store: store,
            validator: defaultResultWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultResultWindowEngine(flags)
        )
    }
}
