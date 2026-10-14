import AcmePlatform
import Foundation

extension Labs {
    /// Moves result audits through their life cycle and keeps a journal of what it did.
    final class ResultAuditManager {
        var store: any ResultAuditStore
        var validator: ResultAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ResultAuditEngine

        init(store: any ResultAuditStore, validator: ResultAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ResultAuditEngine) {
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
                throw Kit.Failure("result audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultAuditStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultAuditStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("result audit \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newResultAuditManager(_ store: any ResultAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ResultAuditManager {
        return ResultAuditManager(
            store: store,
            validator: defaultResultAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultResultAuditEngine(flags)
        )
    }
}
