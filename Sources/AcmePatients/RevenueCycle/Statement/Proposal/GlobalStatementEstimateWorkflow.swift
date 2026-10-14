import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves global statement estimates through their life cycle and keeps a journal of what it did.
    final class GlobalStatementEstimateManager {
        var store: any GlobalStatementEstimateStore
        var validator: GlobalStatementEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalStatementEstimateStore, validator: GlobalStatementEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global statement estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalStatementEstimateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global statement estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalStatementEstimateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newGlobalStatementEstimateManager(_ store: any GlobalStatementEstimateStore, clock: any Kit.Clocks.Clock) -> GlobalStatementEstimateManager {
        return GlobalStatementEstimateManager(
            store: store,
            validator: defaultGlobalStatementEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
