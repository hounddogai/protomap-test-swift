import AcmePlatform
import Foundation

extension Referrals {
    /// Moves global network schedules through their life cycle and keeps a journal of what it did.
    final class GlobalNetworkScheduleService {
        var store: any GlobalNetworkScheduleStore
        var validator: GlobalNetworkScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalNetworkScheduleEngine

        init(store: any GlobalNetworkScheduleStore, validator: GlobalNetworkScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalNetworkScheduleEngine) {
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
                throw Kit.Failure("global network schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalNetworkScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global network schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalNetworkScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global network schedule \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newGlobalNetworkScheduleService(_ store: any GlobalNetworkScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalNetworkScheduleService {
        return GlobalNetworkScheduleService(
            store: store,
            validator: defaultGlobalNetworkScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalNetworkScheduleEngine(flags)
        )
    }
}
