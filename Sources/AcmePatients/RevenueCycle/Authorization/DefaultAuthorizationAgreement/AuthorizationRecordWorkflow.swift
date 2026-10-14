import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves authorization records through their life cycle and keeps a journal of what it did.
    final class AuthorizationRecordWorkflow {
        var store: any AuthorizationRecordStore
        var validator: AuthorizationRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AuthorizationRecordEngine

        init(store: any AuthorizationRecordStore, validator: AuthorizationRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AuthorizationRecordEngine) {
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
                throw Kit.Failure("authorization record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AuthorizationRecordStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AuthorizationRecordStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("authorization record \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newAuthorizationRecordWorkflow(_ store: any AuthorizationRecordStore, clock: any Kit.Clocks.Clock) -> AuthorizationRecordWorkflow {
        return AuthorizationRecordWorkflow(
            store: store,
            validator: defaultAuthorizationRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultAuthorizationRecordEngine()
        )
    }
}
