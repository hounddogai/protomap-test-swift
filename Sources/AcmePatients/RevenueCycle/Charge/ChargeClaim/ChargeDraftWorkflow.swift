import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge drafts through their life cycle and keeps a journal of what it did.
    final class ChargeDraftManager {
        var store: any ChargeDraftStore
        var validator: ChargeDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeDraftEngine

        init(store: any ChargeDraftStore, validator: ChargeDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeDraftEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeDraftStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeDraftStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge draft \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newChargeDraftManager(_ store: any ChargeDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ChargeDraftManager {
        return ChargeDraftManager(
            store: store,
            validator: defaultChargeDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeDraftEngine(flags)
        )
    }
}
