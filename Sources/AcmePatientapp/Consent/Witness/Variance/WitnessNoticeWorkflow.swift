import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness notices through their life cycle and keeps a journal of what it did.
    final class WitnessNoticeService {
        var store: any WitnessNoticeStore
        var validator: WitnessNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessNoticeEngine

        init(store: any WitnessNoticeStore, validator: WitnessNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessNoticeEngine) {
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
                throw Kit.Failure("witness notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessNoticeStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessNoticeStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness notice \(code) not found")
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

    static func newWitnessNoticeService(_ store: any WitnessNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WitnessNoticeService {
        return WitnessNoticeService(
            store: store,
            validator: defaultWitnessNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessNoticeEngine(flags)
        )
    }
}
