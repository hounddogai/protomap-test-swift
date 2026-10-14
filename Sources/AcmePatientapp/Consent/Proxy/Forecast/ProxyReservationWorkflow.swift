import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy reservations through their life cycle and keeps a journal of what it did.
    final class ProxyReservationManager {
        var store: any ProxyReservationStore
        var validator: ProxyReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyReservationEngine

        init(store: any ProxyReservationStore, validator: ProxyReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyReservationEngine) {
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
                throw Kit.Failure("proxy reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyReservationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyReservationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy reservation \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newProxyReservationManager(_ store: any ProxyReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProxyReservationManager {
        return ProxyReservationManager(
            store: store,
            validator: defaultProxyReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyReservationEngine(flags)
        )
    }
}
