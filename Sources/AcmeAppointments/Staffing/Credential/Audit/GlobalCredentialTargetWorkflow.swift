import AcmePlatform
import Foundation

extension Staffing {
    /// Moves global credential targets through their life cycle and keeps a journal of what it did.
    final class GlobalCredentialTargetService {
        var store: any GlobalCredentialTargetStore
        var validator: GlobalCredentialTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalCredentialTargetEngine

        init(store: any GlobalCredentialTargetStore, validator: GlobalCredentialTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalCredentialTargetEngine) {
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
                throw Kit.Failure("global credential target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCredentialTargetStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global credential target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCredentialTargetStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global credential target \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newGlobalCredentialTargetService(_ store: any GlobalCredentialTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalCredentialTargetService {
        return GlobalCredentialTargetService(
            store: store,
            validator: defaultGlobalCredentialTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalCredentialTargetEngine(flags)
        )
    }
}
