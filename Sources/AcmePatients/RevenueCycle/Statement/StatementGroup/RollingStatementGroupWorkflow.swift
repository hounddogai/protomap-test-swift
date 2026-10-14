import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves rolling statement groups through their life cycle and keeps a journal of what it did.
    final class RollingStatementGroupManager {
        var store: any RollingStatementGroupStore
        var validator: RollingStatementGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingStatementGroupEngine

        init(store: any RollingStatementGroupStore, validator: RollingStatementGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingStatementGroupEngine) {
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
                throw Kit.Failure("rolling statement group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingStatementGroupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling statement group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingStatementGroupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling statement group \(code) not found")
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

    static func newRollingStatementGroupManager(_ store: any RollingStatementGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingStatementGroupManager {
        return RollingStatementGroupManager(
            store: store,
            validator: defaultRollingStatementGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingStatementGroupEngine(flags)
        )
    }
}
