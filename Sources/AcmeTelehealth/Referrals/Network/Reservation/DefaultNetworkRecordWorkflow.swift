import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default network records through their life cycle and keeps a journal of what it did.
    final class DefaultNetworkRecordDesk {
        var store: any DefaultNetworkRecordStore
        var validator: DefaultNetworkRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultNetworkRecordEngine

        init(store: any DefaultNetworkRecordStore, validator: DefaultNetworkRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultNetworkRecordEngine) {
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
                throw Kit.Failure("default network record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultNetworkRecordStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default network record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultNetworkRecordStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default network record \(code) not found")
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

    static func newDefaultNetworkRecordDesk(_ store: any DefaultNetworkRecordStore, clock: any Kit.Clocks.Clock) -> DefaultNetworkRecordDesk {
        return DefaultNetworkRecordDesk(
            store: store,
            validator: defaultDefaultNetworkRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultNetworkRecordEngine()
        )
    }
}
