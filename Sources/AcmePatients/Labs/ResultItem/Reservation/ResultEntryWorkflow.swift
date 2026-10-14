import AcmePlatform
import Foundation

extension Labs {
    /// Moves result entries through their life cycle and keeps a journal of what it did.
    final class ResultEntryService {
        var store: any ResultEntryStore
        var validator: ResultEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ResultEntryEngine

        init(store: any ResultEntryStore, validator: ResultEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ResultEntryEngine) {
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
                throw Kit.Failure("result entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultEntryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultEntryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("result entry \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newResultEntryService(_ store: any ResultEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ResultEntryService {
        return ResultEntryService(
            store: store,
            validator: defaultResultEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultResultEntryEngine(flags)
        )
    }
}
