import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy schedules through their life cycle and keeps a journal of what it did.
    final class ProxyScheduleDesk {
        var store: any ProxyScheduleStore
        var validator: ProxyScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyScheduleEngine

        init(store: any ProxyScheduleStore, validator: ProxyScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyScheduleEngine) {
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
                throw Kit.Failure("proxy schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy schedule \(code) not found")
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

    static func newProxyScheduleDesk(_ store: any ProxyScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProxyScheduleDesk {
        return ProxyScheduleDesk(
            store: store,
            validator: defaultProxyScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyScheduleEngine(flags)
        )
    }
}
