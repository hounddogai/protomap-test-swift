import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement manifests through their life cycle and keeps a journal of what it did.
    final class StatementManifestWorkflow {
        var store: any StatementManifestStore
        var validator: StatementManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StatementManifestStore, validator: StatementManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("statement manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementManifestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementManifestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newStatementManifestWorkflow(_ store: any StatementManifestStore, clock: any Kit.Clocks.Clock) -> StatementManifestWorkflow {
        return StatementManifestWorkflow(
            store: store,
            validator: defaultStatementManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
