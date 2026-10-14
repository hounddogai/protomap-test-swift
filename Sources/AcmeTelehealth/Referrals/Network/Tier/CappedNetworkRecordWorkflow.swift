import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped network records through their life cycle and keeps a journal of what it did.
    final class CappedNetworkRecordManager {
        var store: any CappedNetworkRecordStore
        var validator: CappedNetworkRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedNetworkRecordEngine

        init(store: any CappedNetworkRecordStore, validator: CappedNetworkRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedNetworkRecordEngine) {
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
                throw Kit.Failure("capped network record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedNetworkRecordStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped network record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedNetworkRecordStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped network record \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCappedNetworkRecordManager(_ store: any CappedNetworkRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedNetworkRecordManager {
        return CappedNetworkRecordManager(
            store: store,
            validator: defaultCappedNetworkRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedNetworkRecordEngine(flags)
        )
    }
}
