import AcmePlatform
import Foundation

extension Labs {
    /// Moves result requests through their life cycle and keeps a journal of what it did.
    final class ResultRequestService {
        var store: any ResultRequestStore
        var validator: ResultRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ResultRequestEngine

        init(store: any ResultRequestStore, validator: ResultRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ResultRequestEngine) {
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
                throw Kit.Failure("result request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultRequestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultRequestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("result request \(code) not found")
            }
            let result = engine.price(item)
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

    static func newResultRequestService(_ store: any ResultRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ResultRequestService {
        return ResultRequestService(
            store: store,
            validator: defaultResultRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultResultRequestEngine(flags)
        )
    }
}
