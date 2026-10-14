import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling proxy overrides through their life cycle and keeps a journal of what it did.
    final class RollingProxyOverrideManager {
        var store: any RollingProxyOverrideStore
        var validator: RollingProxyOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingProxyOverrideEngine

        init(store: any RollingProxyOverrideStore, validator: RollingProxyOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingProxyOverrideEngine) {
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
                throw Kit.Failure("rolling proxy override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingProxyOverrideStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling proxy override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingProxyOverrideStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling proxy override \(code) not found")
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

    static func newRollingProxyOverrideManager(_ store: any RollingProxyOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingProxyOverrideManager {
        return RollingProxyOverrideManager(
            store: store,
            validator: defaultRollingProxyOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingProxyOverrideEngine(flags)
        )
    }
}
